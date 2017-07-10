#!/usr/bin/env php
<?php

$root = '/usr/local/src/phabricator';
require_once $root.'/scripts/__init_script__.php';

$viewer = PhabricatorUser::getOmnipotentUser();
$source = new PhabricatorLipsumContentSource();

$device = AlmanacDevice::initializeNewDevice();
$xactions = array();

$xactions[] = id(new AlmanacDeviceTransaction())
  ->setTransactionType(AlmanacDeviceTransaction::TYPE_NAME)
  ->setNewValue('test');

id(new AlmanacDeviceEditor())
  ->setActor($viewer)
  ->setContentSource($source)
  ->applyTransactions($device, $xactions);

$key = PhabricatorAuthSSHKey::initializeNewSSHKey($admin, $device);
$key->setIsTrusted(1);
list($public_key, $private_key) = PhabricatorSSHKeyGenerator::generateKeypair();
$public_key = PhabricatorAuthSSHPublicKey::newFromRawKey($public_key);

$xactions = array();

$xactions[] = id(new PhabricatorAuthSSHKeyTransaction())
  ->setTransactionType(PhabricatorTransactions::TYPE_CREATE);

$xactions[] = id(new PhabricatorAuthSSHKeyTransaction())
  ->setTransactionType(PhabricatorAuthSSHKeyTransaction::TYPE_NAME)
  ->setNewValue('id_rsa');

$xactions[] = id(new PhabricatorAuthSSHKeyTransaction())
  ->setTransactionType(PhabricatorAuthSSHKeyTransaction::TYPE_KEY)
  ->setNewValue($public_key->getType().' '.$public_key->getBody().' '.pht('Generated'));

id(new PhabricatorAuthSSHKeyEditor())
  ->setActor($viewer)
  ->setContentSource($source)
  ->applyTransactions($key, $xactions);
